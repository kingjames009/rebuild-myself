package com.rebuildmyself;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 精进 | 全维度人生重塑自律成长 APP — 后端启动类
 */
@SpringBootApplication
@MapperScan("com.rebuildmyself.mapper")
public class RebuildMyselfApplication {

    public static void main(String[] args) {
        SpringApplication.run(RebuildMyselfApplication.class, args);
    }
}
