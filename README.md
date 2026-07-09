# Uptime monitoring

Every 15 minutes, GitHub Actions probes the public sites and APIs behind
MsouWout, MyPlopPlop, HaitiBiznis and 48HoursReady. If a critical target stops
answering, the workflow opens an issue labelled `outage` and keeps commenting on
it until the target recovers, then closes it.

Why this exists: on 2026-07-09 the MsouWout backend (login, chat, tracking,
dispatch) stopped responding entirely, and nobody knew until the client noticed.
Nothing was watching. Now something is.

## What is checked

| Target | Why it matters |
|---|---|
| msouwout.com | The website and the shell the mobile app loads |
| msouwout-backend API | Login, chat, logistics tracking, dispatch |
| myplopplop.com + API | Marketplace |
| 48hoursready.com | Main company site |
| haitibiznis-api | Business directory API |

`haitianamericanlionsclub.org` is listed as *pending* — it is reported on every
run but does not raise an alert, because its DNS is not live yet.

## Notes

Render's free tier spins services down when idle, so a cold start can take up to
a minute. A target is only reported as down after 3 consecutive failures with a
45-second timeout each. One slow response is not an outage.

Run it by hand from the Actions tab (`Uptime` → `Run workflow`) at any time.
