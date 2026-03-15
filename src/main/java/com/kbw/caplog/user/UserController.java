package com.kbw.caplog.user;

import com.kbw.caplog.user.dto.AddFriendRequest;
import com.kbw.caplog.user.dto.FriendDto;
import com.kbw.caplog.user.dto.UpdateProfileRequest;
import com.kbw.caplog.user.dto.UserProfileDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 사용자 프로필 및 친구 API (JWT Bearer 필요)
 * - GET /api/users/me: 내 프로필 조회
 * - PUT /api/users/me: 프로필 수정
 * - GET /api/users/friends: 친구 목록
 * - POST /api/users/friends: 친구 추가 (body: { "userId": "친구userId" })
 * - DELETE /api/users/friends/{userId}: 친구 삭제
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final FriendService friendService;

    @GetMapping("/me")
    public ResponseEntity<UserProfileDto> getMe(Authentication auth) {
        String email = auth != null ? auth.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        return userRepository.findByEmail(email)
                .map(UserProfileDto::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/me")
    public ResponseEntity<UserProfileDto> updateMe(
            Authentication auth,
            @RequestBody UpdateProfileRequest request
    ) {
        String email = auth != null ? auth.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        return userRepository.findByEmail(email)
                .map(user -> {
                    if (request.getNickname() != null) user.setName(request.getNickname());
                    if (request.getGender() != null) user.setGender(request.getGender());
                    if (request.getBirthday() != null) user.setBirthday(request.getBirthday());
                    return userRepository.save(user);
                })
                .map(UserProfileDto::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/friends")
    public ResponseEntity<List<FriendDto>> getFriends(Authentication auth) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        return ResponseEntity.ok(friendService.getFriends(userNo));
    }

    @PostMapping("/friends")
    public ResponseEntity<FriendDto> addFriend(Authentication auth, @RequestBody AddFriendRequest request) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        try {
            return ResponseEntity.ok(friendService.addFriend(userNo, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/friends/{userId}")
    public ResponseEntity<Void> removeFriend(Authentication auth, @PathVariable String userId) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        try {
            friendService.removeFriend(userNo, userId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    private Long resolveUserNo(Authentication auth) {
        if (auth == null || auth.getName() == null || auth.getName().isBlank()) return null;
        return userRepository.findByEmail(auth.getName()).map(User::getUserNo).orElse(null);
    }
}
