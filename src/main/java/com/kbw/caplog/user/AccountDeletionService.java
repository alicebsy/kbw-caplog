package com.kbw.caplog.user;

import com.kbw.caplog.auth.token.RefreshTokenRepository;
import com.kbw.caplog.chat.ChatService;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 회원 탈퇴: 계정과 계정에 딸린 개인정보를 한 트랜잭션에서 지웁니다.
 *
 * <p>App Store 심사지침 5.1.1(v)는 계정을 만들 수 있는 앱이라면 앱 안에서 계정을
 * 삭제할 수 있어야 한다고 요구합니다. 그래서 "비활성화"가 아니라 실제 삭제입니다.
 *
 * <p>외래키가 걸린 순서대로 지웁니다. 중간에 실패하면 트랜잭션이 통째로 되돌아가므로
 * 계정만 남고 데이터가 사라지는 반쪽 상태는 생기지 않습니다.
 */
@Service
@RequiredArgsConstructor
public class AccountDeletionService {

    private final UserRepository userRepository;
    private final FriendshipRepository friendshipRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final ScreenshotRepository screenshotRepository;
    private final ChatService chatService;
    private final EntityManager entityManager;

    @Transactional
    public void deleteAccount(Long userNo) {
        if (userNo == null || !userRepository.existsById(userNo)) {
            throw new IllegalArgumentException("User not found: " + userNo);
        }

        // 1. 채팅: 모든 방에서 나가고 내가 보낸 메시지를 지웁니다.
        chatService.purgeUser(userNo);

        // 2. 친구 관계: 관계는 양쪽 관점의 두 행으로 저장되므로 두 방향 모두 지웁니다.
        //    이걸 빠뜨리면 상대 친구 목록에 사라진 계정이 계속 남습니다.
        friendshipRepository.deleteByOwnerUserNoOrFriendUserNo(userNo, userNo);

        // 3. 카드(스크린샷 레코드)
        screenshotRepository.deleteByUserNo(userNo);

        // 4. 업로드 파일 기록. JPA 엔티티가 없는 테이블이라 네이티브 쿼리로 지웁니다.
        entityManager.createNativeQuery("DELETE FROM screenshot_file WHERE user_id = :userNo")
                .setParameter("userNo", userNo)
                .executeUpdate();

        // 5. 리프레시 토큰을 지워 이 계정으로 토큰을 다시 발급받지 못하게 합니다.
        //    이미 발급된 액세스 토큰은 만료까지 남지만, 계정 행이 없으면 인증이 실패합니다.
        refreshTokenRepository.deleteAllByUserNo(userNo);

        // 6. 계정
        userRepository.deleteById(userNo);
    }
}
