package com.kbw.caplog.chat;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {

    /**
     * 내가 참여한 방 목록. 참여자 전원을 함께 가져옵니다.
     *
     * <p>예전 쿼리는 {@code JOIN r.participants p WHERE p.userNo = :userNo}로 방을 걸렀는데,
     * EntityGraph가 이 조인을 그대로 재사용해서 participants에 <b>나 자신만</b> 담겼습니다.
     * 그 탓에 1:1 방 중복 확인(createRoom)과 방 제목 계산이 어긋났고, 탈퇴 처리에서는
     * "혼자 남은 방"으로 잘못 판단해 방을 지우다 FK 제약에 걸렸습니다.
     * 방 조건은 서브쿼리로 빼서 fetch가 걸러지지 않게 합니다.
     */
    @EntityGraph(attributePaths = "participants")
    @Query("""
            SELECT r FROM ChatRoom r
            WHERE r.id IN (SELECT p.chatRoom.id FROM ChatRoomParticipant p WHERE p.userNo = :userNo)
            ORDER BY r.id DESC
            """)
    List<ChatRoom> findRoomsByParticipantUserNo(Long userNo);
}
