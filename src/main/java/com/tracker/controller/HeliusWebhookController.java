package com.tracker.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.extern.log4j.Log4j2;

@RestController
@RequestMapping("/webhook/solana")
@Log4j2
public class HeliusWebhookController {
 
        @PostMapping
    public ResponseEntity<String> handleWebhook(@RequestBody Map<Object, Object> event,
                                @RequestHeader("X-Helius-Signature") String signature) {
        log.info("Received webhook event: {}", event);
        log.info("Received webhook signature: {}", signature);
        return ResponseEntity.ok("received");
    }
}
