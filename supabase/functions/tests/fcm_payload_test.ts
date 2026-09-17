import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildFcmMessage,
  isUnregisteredError,
  stringifyData,
} from "../_shared/fcm.ts";

Deno.test("stringifyData converte valores para string e ignora nulos", () => {
  const out = stringifyData({
    action: "professional",
    professional_id: "abc",
    skip: null,
    count: 2,
  });
  assertEquals(out, {
    action: "professional",
    professional_id: "abc",
    count: "2",
  });
});

Deno.test("buildFcmMessage inclui notification + data + canal Android", () => {
  const message = buildFcmMessage("tok-1", {
    title: "Nova nutricionista",
    body: "Dra. Ana atende esta semana.",
    data: { action: "professional", campaign_id: "c1" },
  });
  assertEquals(message.message.token, "tok-1");
  assertEquals(message.message.notification.title, "Nova nutricionista");
  assertEquals(message.message.data.action, "professional");
  assertEquals(message.message.android.notification.channelId, "vitta_clube_default");
});

Deno.test("isUnregisteredError detecta token morto", () => {
  assertEquals(isUnregisteredError(404, "{}"), true);
  assertEquals(isUnregisteredError(400, "UNREGISTERED"), true);
  assertEquals(isUnregisteredError(500, "internal"), false);
});
