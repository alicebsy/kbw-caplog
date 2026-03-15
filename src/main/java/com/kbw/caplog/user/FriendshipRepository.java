package com.kbw.caplog.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FriendshipRepository extends JpaRepository<Friendship, Long> {

    @Query("SELECT f FROM Friendship f JOIN FETCH f.friend WHERE f.ownerUserNo = :ownerUserNo")
    List<Friendship> findByOwnerUserNo(@Param("ownerUserNo") Long ownerUserNo);

    Optional<Friendship> findByOwnerUserNoAndFriendUserNo(Long ownerUserNo, Long friendUserNo);

    void deleteByOwnerUserNoAndFriendUserNo(Long ownerUserNo, Long friendUserNo);

    boolean existsByOwnerUserNoAndFriendUserNo(Long ownerUserNo, Long friendUserNo);
}
