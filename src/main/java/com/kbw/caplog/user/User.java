package com.kbw.caplog.user;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "users")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_no")
    private Long userNo;

    @Column(unique = true, nullable = false, length = 255)
    private String email;

    @Column(nullable = false, length = 255)
    private String password;

    @Column(name = "user_id", unique = true, nullable = false, length = 50)
    private String userId;

    @Column(length = 100)
    private String name;

    @Column(length = 1)
    private String gender;  // M, F

    @Column(name = "birthday")
    private LocalDate birthday;
}
