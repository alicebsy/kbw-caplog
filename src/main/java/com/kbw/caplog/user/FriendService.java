package com.kbw.caplog.user;

import com.kbw.caplog.user.dto.AddFriendRequest;
import com.kbw.caplog.user.dto.FriendDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FriendService {

    private final UserRepository userRepository;
    private final FriendshipRepository friendshipRepository;

    public List<FriendDto> getFriends(Long ownerUserNo) {
        return friendshipRepository.findByOwnerUserNo(ownerUserNo).stream()
                .map(Friendship::getFriend)
                .filter(f -> f != null)
                .map(FriendDto::from)
                .sorted((left, right) -> left.getName().compareToIgnoreCase(right.getName()))
                .collect(Collectors.toList());
    }

    @Transactional
    public FriendDto addFriend(Long ownerUserNo, AddFriendRequest request) {
        if (request.getUserId() == null || request.getUserId().isBlank()) {
            throw new IllegalArgumentException("userId is required");
        }
        User owner = userRepository.findById(ownerUserNo)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        User friendUser = userRepository.findByUserId(request.getUserId().trim())
                .orElseThrow(() -> new IllegalArgumentException("Friend user not found: " + request.getUserId()));

        if (owner.getUserNo().equals(friendUser.getUserNo())) {
            throw new IllegalArgumentException("Cannot add yourself as friend");
        }
        boolean ownerHasFriend = friendshipRepository.existsByOwnerUserNoAndFriendUserNo(
                ownerUserNo,
                friendUser.getUserNo()
        );
        boolean friendHasOwner = friendshipRepository.existsByOwnerUserNoAndFriendUserNo(
                friendUser.getUserNo(),
                ownerUserNo
        );
        if (ownerHasFriend && friendHasOwner) {
            throw new IllegalArgumentException("Already friends");
        }

        if (!ownerHasFriend) {
            friendshipRepository.save(Friendship.builder()
                    .ownerUserNo(ownerUserNo)
                    .friendUserNo(friendUser.getUserNo())
                    .build());
        }
        if (!friendHasOwner) {
            friendshipRepository.save(Friendship.builder()
                    .ownerUserNo(friendUser.getUserNo())
                    .friendUserNo(ownerUserNo)
                    .build());
        }
        return FriendDto.from(friendUser);
    }

    @Transactional
    public void removeFriend(Long ownerUserNo, String friendUserId) {
        User friendUser = userRepository.findByUserId(friendUserId)
                .orElseThrow(() -> new IllegalArgumentException("Friend user not found: " + friendUserId));
        if (!friendshipRepository.existsByOwnerUserNoAndFriendUserNo(ownerUserNo, friendUser.getUserNo())) {
            throw new IllegalArgumentException("Friendship not found");
        }
        friendshipRepository.deleteByOwnerUserNoAndFriendUserNo(ownerUserNo, friendUser.getUserNo());
        friendshipRepository.deleteByOwnerUserNoAndFriendUserNo(friendUser.getUserNo(), ownerUserNo);
    }
}
