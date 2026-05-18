package com.rebuildmyself.util;

import cn.hutool.core.util.StrUtil;
import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpResponse;
import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * AI 大模型调用工具 — 对接通用Chat API, 结构化数据传入输出复盘报告
 */
@Slf4j
@Component
public class AiUtil {

    @Value("${ai.api-url}")
    private String apiUrl;

    @Value("${ai.api-key}")
    private String apiKey;

    @Value("${ai.model}")
    private String model;

    /**
     * 调用AI大模型生成复盘报告
     * @param systemPrompt 系统提示词(心理学专业背景)
     * @param userData 用户全量聚合数据JSON
     * @return AI生成的复盘报告文本
     */
    public String generateReport(String systemPrompt, String userData) {
        log.info("AI call START — url={}, model={}, promptLen={}, dataLen={}",
                apiUrl, model, systemPrompt.length(), userData.length());

        JSONObject body = new JSONObject();
        body.set("model", model);

        JSONArray messages = new JSONArray();

        JSONObject sysMsg = new JSONObject();
        sysMsg.set("role", "system");
        sysMsg.set("content", systemPrompt);
        messages.add(sysMsg);

        JSONObject userMsg = new JSONObject();
        userMsg.set("role", "user");
        userMsg.set("content", userData);
        messages.add(userMsg);

        body.set("messages", messages);
        body.set("temperature", 0.7);
        body.set("max_tokens", 8192);

        long start = System.currentTimeMillis();
        try {
            HttpResponse response = HttpRequest.post(apiUrl)
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .body(body.toString())
                    .timeout(120000)
                    .execute();

            long elapsed = System.currentTimeMillis() - start;
            log.info("AI response received — status={}, elapsed={}ms", response.getStatus(), elapsed);

            if (response.isOk()) {
                JSONObject result = JSONUtil.parseObj(response.body());
                JSONArray choices = result.getJSONArray("choices");
                if (choices != null && !choices.isEmpty()) {
                    JSONObject first = choices.getJSONObject(0);
                    JSONObject message = first.getJSONObject("message");
                    String content = message.getStr("content", "");
                    log.info("AI call SUCCESS — contentLen={}, elapsed={}ms", content.length(), elapsed);
                    return content;
                }
                log.warn("AI response had no choices — body preview: {}",
                        response.body().substring(0, Math.min(500, response.body().length())));
            }
            log.error("AI API error — status={}, body preview: {}",
                    response.getStatus(),
                    response.body().substring(0, Math.min(500, response.body().length())));
            return null;
        } catch (Exception e) {
            long elapsed = System.currentTimeMillis() - start;
            log.error("AI API call FAILED — elapsed={}ms, errorType={}, message={}",
                    elapsed, e.getClass().getSimpleName(), e.getMessage(), e);
            return null;
        }
    }

    /**
     * 简单对话 — 用于心理干预建议等场景
     */
    public String chat(String prompt) {
        return generateReport("你是一位专业的认知行为心理学顾问，请用温和、共情的语气给出建议。", prompt);
    }
}
