package com.kbw.caplog.user;

import com.kbw.caplog.user.dto.UpdateProfileRequest;
import com.kbw.caplog.user.dto.UserProfileDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * 사용자 프로필 API (JWT Bearer 필요)
 * - GET /api/users/me: 내 프로필 조회
 * - PUT /api/users/me: 프로필 수정 (nickname, gender, birthday)
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

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
}
