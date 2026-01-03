package com.carpool.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import jakarta.annotation.PostConstruct;
import java.io.IOException;

@Configuration
public class FirebaseConfig {

    @Value("${firebase.service-account-path}")
    private Resource serviceAccount;

    @PostConstruct
    public void init() throws IOException {
        // 防止热启动/多次初始化报错
        if (!FirebaseApp.getApps().isEmpty()) return;

        GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount.getInputStream());

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(credentials)
                .build();

        FirebaseApp.initializeApp(options);
    }
}
