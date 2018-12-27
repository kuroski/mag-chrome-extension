import "./magnetis.css";
import store from "store";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";

document.addEventListener("DOMContentLoaded", () => {
  let credentials;

  if (store.get("mag-credentials")) {
    credentials = store.get("mag-credentials");
  } else {
    credentials = null;
  }

  const app = Elm.Main.init({
    node: document.getElementById("elm"),
    flags: {
      serverUrl: process.env.ELM_APP_SERVER_URL || "http://localhost:4000",
      credentials
    }
  });

  app.ports.setLocalstorage.subscribe(data => {
    store.set("mag-credentials", data);
  });

  app.ports.removeLocalstorage.subscribe(data => {
    store.clearAll();
  });

  app.ports.setBadge.subscribe(({ days = 0 }) => {
    if (!chrome || !chrome.browserAction) return;
    chrome.browserAction.setBadgeText({
      text: days.toString()
    });

    const now = new Date(
      new Date().getFullYear(),
      new Date().getMonth(),
      new Date().getDate()
    );
    if (!store.get("badgeDate") || new Date(store.get("badgeDate")) !== now) {
      store.set("badgeDate", now.getTime());
      store.set("badgeDay", days);
    }
  });

  registerServiceWorker();
});
