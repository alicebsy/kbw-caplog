package com.kbw.caplog.chat;

import com.kbw.caplog.user.User;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "chat_room_participants", uniqueConstraints = {
    @UniqueConstraint(columnNames = { "chat_room_id", "user_no" })
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatRoomParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "chat_room_id", nullable = false)
    private ChatRoom chatRoom;

    @Column(name = "user_no", nullable = false)
    private Long userNo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_no", insertable = false, updatable = false)
    private User user;

    @Column(name = "last_read_at")
    private java.time.Instant lastReadAt;
}
