package com.kbw.caplog.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kbw.caplog.card.dto.CardDto;
import com.kbw.caplog.card.service.CardService;
import com.kbw.caplog.chat.dto.CreateChatRequest;
import com.kbw.caplog.chat.dto.SendMessageRequest;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
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
        CardService cardService = mock(CardService.class);
        ChatService service = new ChatService(
                roomRepository,
                messageRepository,
                userRepository,
                cardService,
                new ObjectMapper().findAndRegisterModules()
        );

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

    @Test
    void storesOwnedCardSnapshotAndReturnsItInMessage() {
        ChatRoomRepository roomRepository = mock(ChatRoomRepository.class);
        ChatMessageRepository messageRepository = mock(ChatMessageRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        CardService cardService = mock(CardService.class);
        ChatService service = new ChatService(
                roomRepository,
                messageRepository,
                userRepository,
                cardService,
                new ObjectMapper().findAndRegisterModules()
        );

        ChatRoom room = ChatRoom.builder()
                .id(10L)
                .createdAt(Instant.parse("2026-07-28T00:00:00Z"))
                .build();
        room.getParticipants().add(ChatRoomParticipant.builder().chatRoom(room).userNo(1L).build());
        room.getParticipants().add(ChatRoomParticipant.builder().chatRoom(room).userNo(2L).build());
        CardDto card = CardDto.builder()
                .id("00000000-0000-0000-0000-00000000002a")
                .title("공유 카드")
                .summary("채팅 카드 테스트")
                .category("Info")
                .subcategory("카페")
                .tags(List.of("테스트"))
                .fields(Map.of("장소명", "테스트 카페"))
                .createdAt(Instant.parse("2026-07-28T00:00:00Z"))
                .updatedAt(Instant.parse("2026-07-28T00:00:00Z"))
                .screenshotURLs(List.of())
                .build();

        when(roomRepository.findById(10L)).thenReturn(Optional.of(room));
        when(cardService.findOwnedCardByExternalId(1L, card.getId())).thenReturn(card);
        when(messageRepository.save(any(ChatMessage.class))).thenAnswer(invocation -> {
            ChatMessage saved = invocation.getArgument(0);
            saved.setId(99L);
            return saved;
        });
        User sender = User.builder()
                .userNo(1L)
                .userId("me-user")
                .name("나")
                .email("me@example.com")
                .password("encoded")
                .build();
        when(userRepository.findById(1L)).thenReturn(Optional.of(sender));

        SendMessageRequest request = new SendMessageRequest();
        request.setCardId(card.getId());

        var result = service.sendMessage(10L, 1L, request);

        assertEquals("99", result.getId());
        assertNotNull(result.getCard());
        assertEquals("공유 카드", result.getCard().getTitle());
        verify(cardService).findOwnedCardByExternalId(1L, card.getId());
        verify(messageRepository).save(any(ChatMessage.class));
    }
}
