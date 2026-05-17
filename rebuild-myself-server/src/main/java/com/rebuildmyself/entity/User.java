package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户表
 */
@Data
@TableName("user")
public class User {

    @TableId(type = IdType.AUTO)
    private Long userId;
    private String phone;
    private String password;
    private String nickname;
    private String avatar;
    private String longTermGoal;
    private String localLockPwd;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    private LocalDateTime lastLoginTime;
    private java.math.BigDecimal height;
    private java.math.BigDecimal weight;
    private String healthNote;
}
