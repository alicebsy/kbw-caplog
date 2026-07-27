package com.kbw.caplog.chat;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kbw.caplog.card.dto.CardDto;
import com.kbw.caplog.card.service.CardService;
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
    private final CardService cardService;
    private final ObjectMapper objectMapper;

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

        if (participantUserNos.size() == 2) {
            Optional<ChatRoom> existingRoom = chatRoomRepository.findRoomsByParticipantUserNo(currentUserNo)
                    .stream()
                    .filter(room -> room.getParticipants().stream()
                            .map(ChatRoomParticipant::getUserNo)
                            .collect(Collectors.toSet())
                            .equals(participantUserNos))
                    .findFirst();
            if (existingRoom.isPresent()) {
                return toSummaryDto(existingRoom.get(), currentUserNo);
            }
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

        return toSummaryDto(room, currentUserNo);
    }

    public List<ChatSummaryDto> listRooms(Long currentUserNo) {
        List<ChatRoom> rooms = chatRoomRepository.findRoomsByParticipantUserNo(currentUserNo);
        List<ChatSummaryDto> result = rooms.stream()
                .map(room -> toSummaryDto(room, currentUserNo))
                .collect(Collectors.toCollection(ArrayList::new));
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
        if (text.isEmpty()) text = null;
        String cardId = request.getCardId() != null ? request.getCardId().trim() : "";
        if (cardId.isEmpty()) cardId = null;
        if (text == null && cardId == null) {
            throw new IllegalArgumentException("Message content required");
        }

        String cardSnapshot = null;
        if (cardId != null) {
            CardDto card = cardService.findOwnedCardByExternalId(currentUserNo, cardId);
            cardSnapshot = serializeCard(card);
        }

        ChatMessage msg = ChatMessage.builder()
                .chatRoom(room)
                .senderUserNo(currentUserNo)
                .text(text)
                .cardId(cardId)
                .cardSnapshot(cardSnapshot)
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

    private ChatSummaryDto toSummaryDto(ChatRoom room, Long currentUserNo) {
        ChatMessage lastMessage = messageRepository.findByChatRoomIdOrderByCreatedAtAsc(room.getId())
                .stream()
                .reduce((first, second) -> second)
                .orElse(null);
        List<String> participantIds = room.getParticipants().stream()
                .map(ChatRoomParticipant::getUserNo)
                .map(userNo -> userRepository.findById(userNo)
                        .map(User::getUserId)
                        .orElse(String.valueOf(userNo)))
                .toList();

        return ChatSummaryDto.builder()
                .id(String.valueOf(room.getId()))
                .title(buildRoomTitle(room, currentUserNo))
                .lastMessage(lastMessage != null && lastMessage.getText() != null ? lastMessage.getText() : "")
                .lastMessageCardTitle(lastMessage != null ? cardTitle(lastMessage) : null)
                .updatedAt(lastMessage != null ? lastMessage.getCreatedAt() : room.getCreatedAt())
                .unreadCount(countUnread(room, currentUserNo, lastMessage))
                .participantIds(participantIds)
                .avatarUrl(null)
                .build();
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
                .card(deserializeCard(m.getCardSnapshot()))
                .createdAt(m.getCreatedAt())
                .build();
    }

    private String serializeCard(CardDto card) {
        try {
            return objectMapper.writeValueAsString(card);
        } catch (JsonProcessingException error) {
            throw new IllegalStateException("Failed to serialize card", error);
        }
    }

    private CardDto deserializeCard(String snapshot) {
        if (snapshot == null || snapshot.isBlank()) return null;
        try {
            return objectMapper.readValue(snapshot, CardDto.class);
        } catch (JsonProcessingException error) {
            return null;
        }
    }

    private String cardTitle(ChatMessage message) {
        CardDto card = deserializeCard(message.getCardSnapshot());
        return card != null ? card.getTitle() : null;
    }
}
