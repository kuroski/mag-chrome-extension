import "./magnetis.css";
import store from "store";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";

const loadCredentials = () => store.get("mag-credentials") || null;

document.addEventListener("DOMContentLoaded", () => {
  const credentials = loadCredentials();
  const showNotification = (days = 0) => {
    if (
      !window.Notification ||
      Notification.permission === "denied" ||
      days > 0
    )
      return;

    Notification.requestPermission(status => {
      const notification = new Notification("Vamos fazer uma nova aplicação?", {
        body:
          "Chegou o dia em que você nos pediu para lembrar de fazer uma nova aplicação na sua conta. Para isto, basta clicar nesta notificação"
      });

      notification.onclick = event => {
        event.preventDefault();
        window.open("https://magnetis.com.br/nova-aplicacao", "_blank");
      };
    });
  };
  const setBadge = (days = 0) => {
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
  };

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
    showNotification(days);
    setBadge(days);
  });

  registerServiceWorker();
});
