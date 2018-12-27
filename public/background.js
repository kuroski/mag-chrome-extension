(() => {
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

  if (!badgeDate || !badgeDay || !chrome || !chrome.browserAction) return;

  if (badgeDate < now && newDay >= 0) {
    chrome.browserAction.setBadgeText({ text: newDay.toString() });
    localStorage.setItem("badgeDate", now.getTime());
    localStorage.setItem("badgeDay", newDay);
  }
})();
