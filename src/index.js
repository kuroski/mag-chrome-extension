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

  registerServiceWorker();
});
