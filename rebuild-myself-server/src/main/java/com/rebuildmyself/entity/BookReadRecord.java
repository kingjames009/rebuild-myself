package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("book_read_record")
public class BookReadRecord {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Integer bookType;
    private String bookName;
    private Integer readMinutes;
    private Integer readProgress;
    private String bookNotes;
    private Integer escapeStatus;
    private LocalDate recordDate;
    private LocalDateTime createTime;
}
