package com.cstore.app.dto;

/** Danh tính đã được nhà cung cấp Google/Facebook xác minh. */
public record VerifiedSocialIdentity(String subject, String email, String name) {}
