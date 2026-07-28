package com.kbw.caplog.user;

import com.kbw.caplog.user.dto.AddFriendRequest;
import com.kbw.caplog.user.dto.FriendDto;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class FriendServiceTest {

    @Test
    void addsFriendshipForBothUsers() {
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        FriendService service = new FriendService(users, friendships);
        User owner = user(1L, "owner", "사용자");
        User friend = user(2L, "friend", "친구");
        when(users.findById(1L)).thenReturn(Optional.of(owner));
        when(users.findByUserId("friend")).thenReturn(Optional.of(friend));

        FriendDto result = service.addFriend(1L, request("friend"));

        ArgumentCaptor<Friendship> captor = ArgumentCaptor.forClass(Friendship.class);
        verify(friendships, times(2)).save(captor.capture());
        List<Friendship> saved = captor.getAllValues();
        assertEquals(1L, saved.get(0).getOwnerUserNo());
        assertEquals(2L, saved.get(0).getFriendUserNo());
        assertEquals(2L, saved.get(1).getOwnerUserNo());
        assertEquals(1L, saved.get(1).getFriendUserNo());
        assertEquals("friend", result.getId());
    }

    @Test
    void repairsMissingReverseFriendship() {
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        FriendService service = new FriendService(users, friendships);
        when(users.findById(1L)).thenReturn(Optional.of(user(1L, "owner", "사용자")));
        when(users.findByUserId("friend")).thenReturn(Optional.of(user(2L, "friend", "친구")));
        when(friendships.existsByOwnerUserNoAndFriendUserNo(1L, 2L)).thenReturn(true);
        when(friendships.existsByOwnerUserNoAndFriendUserNo(2L, 1L)).thenReturn(false);

        service.addFriend(1L, request("friend"));

        ArgumentCaptor<Friendship> captor = ArgumentCaptor.forClass(Friendship.class);
        verify(friendships).save(captor.capture());
        assertEquals(2L, captor.getValue().getOwnerUserNo());
        assertEquals(1L, captor.getValue().getFriendUserNo());
    }

    @Test
    void rejectsAddingSelf() {
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        FriendService service = new FriendService(users, friendships);
        User owner = user(1L, "owner", "사용자");
        when(users.findById(1L)).thenReturn(Optional.of(owner));
        when(users.findByUserId("owner")).thenReturn(Optional.of(owner));

        assertThrows(IllegalArgumentException.class, () -> service.addFriend(1L, request("owner")));
        verify(friendships, never()).save(org.mockito.ArgumentMatchers.any(Friendship.class));
    }

    @Test
    void removesFriendshipForBothUsers() {
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        FriendService service = new FriendService(users, friendships);
        when(users.findByUserId("friend")).thenReturn(Optional.of(user(2L, "friend", "친구")));
        when(friendships.existsByOwnerUserNoAndFriendUserNo(1L, 2L)).thenReturn(true);

        service.removeFriend(1L, "friend");

        verify(friendships).deleteByOwnerUserNoAndFriendUserNo(1L, 2L);
        verify(friendships).deleteByOwnerUserNoAndFriendUserNo(2L, 1L);
    }

    @Test
    void rejectsRemovingUnknownFriendship() {
        UserRepository users = mock(UserRepository.class);
        FriendshipRepository friendships = mock(FriendshipRepository.class);
        FriendService service = new FriendService(users, friendships);
        when(users.findByUserId("friend")).thenReturn(Optional.of(user(2L, "friend", "친구")));

        assertThrows(IllegalArgumentException.class, () -> service.removeFriend(1L, "friend"));
        verify(friendships, never()).deleteByOwnerUserNoAndFriendUserNo(1L, 2L);
    }

    private static User user(Long userNo, String userId, String name) {
        return User.builder()
                .userNo(userNo)
                .userId(userId)
                .name(name)
                .email(userId + "@example.com")
                .password("password")
                .build();
    }

    private static AddFriendRequest request(String userId) {
        AddFriendRequest request = new AddFriendRequest();
        request.setUserId(userId);
        return request;
    }
}
