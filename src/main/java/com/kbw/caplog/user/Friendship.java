package com.kbw.caplog.user;

import jakarta.persistence.*;
import lombok.*;

/**
 * 친구 관계 (A-B 양방향 저장하지 않고, 요청한 사람 기준으로 한 방향만 저장)
 * - owner: 친구 목록을 가진 사용자
 * - friend: 추가된 친구
 */
@Entity
@Table(name = "friendships", uniqueConstraints = {
    @UniqueConstraint(columnNames = { "owner_user_no", "friend_user_no" })
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Friendship {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "owner_user_no", nullable = false)
    private Long ownerUserNo;

    @Column(name = "friend_user_no", nullable = false)
    private Long friendUserNo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_user_no", insertable = false, updatable = false)
    private User owner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "friend_user_no", insertable = false, updatable = false)
    private User friend;
}
