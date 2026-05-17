package com.rebuildmyself.util;

import cn.hutool.crypto.SecureUtil;
import cn.hutool.crypto.symmetric.AES;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

/**
 * AES 加密工具 — 私密内容高强度加密
 */
@Component
public class AESUtil {

    private static final String FIXED_KEY = "RebuildMyselfAES2025SecretKey!";

    private final AES aes;

    public AESUtil() {
        this.aes = SecureUtil.aes(FIXED_KEY.getBytes(StandardCharsets.UTF_8));
    }

    /** 加密 */
    public String encrypt(String plainText) {
        if (plainText == null) return null;
        return aes.encryptBase64(plainText);
    }

    /** 解密 */
    public String decrypt(String cipherText) {
        if (cipherText == null) return null;
        return aes.decryptStr(cipherText);
    }
}
