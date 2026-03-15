package com.kbw.caplog.chat;

import com.kbw.caplog.chat.dto.*;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository messageRepository;
    private final UserRepository userRepository;

    @Transactional
    public ChatSummaryDto createRoom(Long currentUserNo, CreateChatRequest request) {
        User currentUser = userRepository.findById(currentUserNo)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Set<Long> participantUserNos = new HashSet<>();
        participantUserNos.add(currentUserNo);
        if (request.getParticipantUserIds() != null) {
            for (String uid : request.getParticipantUserIds()) {
                if (uid == null || uid.isBlank()) continue;
                userRepository.findByUserId(uid.trim())
                        .map(User::getUserNo)
                        .ifPresent(participantUserNos::add);
            }
        }
        if (participantUserNos.size() < 2) {
            throw new IllegalArgumentException("At least 2 participants required");
        }

        ChatRoom room = ChatRoom.builder()
                .createdAt(Instant.now())
                .build();
        room = chatRoomRepository.save(room);

        for (Long userNo : participantUserNos) {
            ChatRoomParticipant p = ChatRoomParticipant.builder()
                    .chatRoom(room)
                    .userNo(userNo)
                    .build();
            room.getParticipants().add(p);
        }
        chatRoomRepository.save(room);

        String title = buildRoomTitle(room, currentUserNo);
        return ChatSummaryDto.builder()
                .id(String.valueOf(room.getId()))
                .title(title)
                .lastMessage("")
                .updatedAt(room.getCreatedAt())
                .unreadCount(0)
                .avatarUrl(null)
                .build();
    }

    public List<ChatSummaryDto> listRooms(Long currentUserNo) {
        List<ChatRoom> rooms = chatRoomRepository.findRoomsByParticipantUserNo(currentUserNo);
        List<ChatSummaryDto> result = new ArrayList<>();
        for (ChatRoom room : rooms) {
            ChatMessage lastMsg = messageRepository.findByChatRoomIdOrderByCreatedAtAsc(room.getId())
                    .stream().reduce((a, b) -> b).orElse(null);
            String title = buildRoomTitle(room, currentUserNo);
            int unread = countUnread(room, currentUserNo, lastMsg);
            result.add(ChatSummaryDto.builder()
                    .id(String.valueOf(room.getId()))
                    .title(title)
                    .lastMessage(lastMsg != null ? (lastMsg.getText() != null ? lastMsg.getText() : "") : "")
                    .updatedAt(lastMsg != null ? lastMsg.getCreatedAt() : room.getCreatedAt())
                    .unreadCount(unread)
                    .avatarUrl(null)
                    .build());
        }
        result.sort(Comparator.comparing(ChatSummaryDto::getUpdatedAt).reversed());
        return result;
    }

    public List<ChatMessageDto> getMessages(Long roomId, Long currentUserNo) {
        ChatRoom room = chatRoomRepository.findById(roomId).orElseThrow(() -> new IllegalArgumentException("Room not found"));
        boolean isParticipant = room.getParticipants().stream().anyMatch(p -> p.getUserNo().equals(currentUserNo));
        if (!isParticipant) throw new IllegalArgumentException("Not a participant");
        return messageRepository.findByChatRoomIdOrderByCreatedAtAsc(roomId).stream()
                .map(m -> toMessageDto(m, roomId))
                .collect(Collectors.toList());
    }

    @Transactional
    public ChatMessageDto sendMessage(Long roomId, Long currentUserNo, SendMessageRequest request) {
        ChatRoom room = chatRoomRepository.findById(roomId).orElseThrow(() -> new IllegalArgumentException("Room not found"));
        boolean isParticipant = room.getParticipants().stream().anyMatch(p -> p.getUserNo().equals(currentUserNo));
        if (!isParticipant) throw new IllegalArgumentException("Not a participant");
        String text = request.getText() != null ? request.getText().trim() : "";
        ChatMessage msg = ChatMessage.builder()
                .chatRoom(room)
                .senderUserNo(currentUserNo)
                .text(text)
                .createdAt(Instant.now())
                .build();
        msg = messageRepository.save(msg);
        return toMessageDto(msg, roomId);
    }

    @Transactional
    public void markRead(Long roomId, Long currentUserNo) {
        ChatRoom room = chatRoomRepository.findById(roomId).orElseThrow(() -> new IllegalArgumentException("Room not found"));
        room.getParticipants().stream()
                .filter(p -> p.getUserNo().equals(currentUserNo))
                .forEach(p -> p.setLastReadAt(Instant.now()));
        chatRoomRepository.save(room);
    }

    private String buildRoomTitle(ChatRoom room, Long currentUserNo) {
        List<String> names = room.getParticipants().stream()
                .filter(p -> !p.getUserNo().equals(currentUserNo))
                .map(p -> userRepository.findById(p.getUserNo()).map(User::getName).orElse("?"))
                .filter(Objects::nonNull)
                .sorted()
                .collect(Collectors.toList());
        if (names.isEmpty()) return "채팅방";
        if (names.size() == 1) return names.get(0);
        return String.join(", ", names);
    }

    private int countUnread(ChatRoom room, Long currentUserNo, ChatMessage lastMessage) {
        if (lastMessage == null || lastMessage.getSenderUserNo().equals(currentUserNo)) return 0;
        Optional<Instant> myLastRead = room.getParticipants().stream()
                .filter(p -> p.getUserNo().equals(currentUserNo))
                .map(ChatRoomParticipant::getLastReadAt)
                .findFirst();
        if (myLastRead.isEmpty()) return 1;
        return lastMessage.getCreatedAt().isAfter(myLastRead.get()) ? 1 : 0;
    }

    private ChatMessageDto toMessageDto(ChatMessage m, Long roomId) {
        String senderId = userRepository.findById(m.getSenderUserNo())
                .map(User::getUserId)
                .orElse(String.valueOf(m.getSenderUserNo()));
        String senderName = userRepository.findById(m.getSenderUserNo())
                .map(User::getName)
                .orElse(senderId);
        return ChatMessageDto.builder()
                .id(String.valueOf(m.getId()))
                .chatId(String.valueOf(roomId))
                .senderId(senderId)
                .senderName(senderName != null ? senderName : senderId)
                .text(m.getText() != null ? m.getText() : "")
                .createdAt(m.getCreatedAt())
                .build();
    }
}
