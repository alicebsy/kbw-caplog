package com.kbw.caplog.chat;

import com.kbw.caplog.chat.dto.CreateChatRequest;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ChatServiceTest {

    @Test
    void reusesRoomWithSameParticipantsAndReturnsTheirUserIds() {
        ChatRoomRepository roomRepository = mock(ChatRoomRepository.class);
        ChatMessageRepository messageRepository = mock(ChatMessageRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        ChatService service = new ChatService(roomRepository, messageRepository, userRepository);

        User me = User.builder()
                .userNo(1L)
                .userId("me-user")
                .name("나")
                .email("me@example.com")
                .password("encoded")
                .build();
        User friend = User.builder()
                .userNo(2L)
                .userId("friend-user")
                .name("친구")
                .email("friend@example.com")
                .password("encoded")
                .build();
        ChatRoom room = ChatRoom.builder()
                .id(10L)
                .createdAt(Instant.parse("2026-07-28T00:00:00Z"))
                .build();
        room.getParticipants().add(ChatRoomParticipant.builder().chatRoom(room).userNo(1L).build());
        room.getParticipants().add(ChatRoomParticipant.builder().chatRoom(room).userNo(2L).build());

        when(userRepository.findById(1L)).thenReturn(Optional.of(me));
        when(userRepository.findById(2L)).thenReturn(Optional.of(friend));
        when(userRepository.findByUserId("friend-user")).thenReturn(Optional.of(friend));
        when(roomRepository.findRoomsByParticipantUserNo(1L)).thenReturn(List.of(room));
        when(messageRepository.findByChatRoomIdOrderByCreatedAtAsc(10L)).thenReturn(List.of());

        CreateChatRequest request = new CreateChatRequest();
        request.setParticipantUserIds(List.of("friend-user"));

        var result = service.createRoom(1L, request);

        assertEquals("10", result.getId());
        assertEquals("친구", result.getTitle());
        assertEquals(2, result.getParticipantIds().size());
        assertTrue(result.getParticipantIds().containsAll(List.of("me-user", "friend-user")));
        verify(roomRepository, never()).save(any(ChatRoom.class));
    }
}
