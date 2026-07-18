# enphaseR: Access Solar Production Data from the Enphase Enlighten Cloud API

Fetch solar energy production data for your own Enphase system from the
official Enphase Enlighten cloud API (v4). Handles the OAuth2
authorization flow with a one-time interactive browser step, then keeps
access and refresh tokens perpetually fresh by rotating them on every
request, so a scheduled job never needs manual re-authentication.
Returns tidy tibbles of 15-minute production intervals, system lists,
and system summaries. Code mostly re-written by Claude from earlier
scripts Sharon wrote.

## See also

Useful links:

- <https://smach.github.io/enphaseR/>

## Author

**Maintainer**: Sharon Machlis <smachlis@gmail.com>
