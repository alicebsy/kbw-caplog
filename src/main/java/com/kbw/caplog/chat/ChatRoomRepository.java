package com.kbw.caplog.chat;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {

    @EntityGraph(attributePaths = "participants")
    @Query("SELECT DISTINCT r FROM ChatRoom r JOIN r.participants p WHERE p.userNo = :userNo ORDER BY r.id DESC")
    List<ChatRoom> findRoomsByParticipantUserNo(Long userNo);
}
