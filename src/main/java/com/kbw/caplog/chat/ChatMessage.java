package com.kbw.caplog.chat;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "chat_messages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "chat_room_id", nullable = false)
    private ChatRoom chatRoom;

    @Column(name = "sender_user_no", nullable = false)
    private Long senderUserNo;

    @Column(length = 2000)
    private String text;

    @Column(name = "card_id", length = 36)
    private String cardId;

    @Column(name = "card_snapshot", columnDefinition = "TEXT")
    private String cardSnapshot;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
