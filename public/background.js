(() => {
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

  const millisecondsToDays = time => {
    const DAY_MILLISECONDS = 24 * 60 * 60 * 1000;
    return Math.floor(time / DAY_MILLISECONDS);
  };

  const now = new Date(
    new Date().getFullYear(),
    new Date().getMonth(),
    new Date().getDate()
  );
  now.setHours(0);
  now.setMinutes(0);
  now.setSeconds(0);

  const badgeDate = new Date(parseInt(localStorage.getItem("badgeDate")));
  badgeDate.setHours(0);
  badgeDate.setMinutes(0);
  badgeDate.setSeconds(0);

  const badgeDay = localStorage.getItem("badgeDay");
  const diffDates = Math.abs(now - badgeDate);
  const newDay = badgeDay - millisecondsToDays(diffDates);
  showNotification(newDay);

  if (!badgeDate || !badgeDay || !chrome || !chrome.browserAction) return;

  if (badgeDate < now && newDay >= 0) {
    chrome.browserAction.setBadgeText({ text: newDay.toString() });
    localStorage.setItem("badgeDate", now.getTime());
    localStorage.setItem("badgeDay", newDay);
  }
})();
