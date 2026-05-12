# Online Shop Project Workflow

Use these project-specific rules together with the global Codex workflow.

## Chrome Verification

- Prefer Chrome for visual checks, but reuse an existing Chrome window/tab when practical.
- Do not open a new Chrome window for every UI change. Vite hot module replacement should update the existing page after edits.
- Before opening or refreshing Chrome, confirm the Vite dev server URL responds successfully.
- Only open a new window/tab when the route changed, the server restarted, the page is stuck, login/session state must be reset, or a first-load check is needed.

## Design Quality

- For user-facing UI changes, run a design pass even when the user does not explicitly ask for visual polish.
- The design pass should check task clarity, information hierarchy, spacing rhythm, typography scale, responsive behavior, text overflow, empty/loading/error states, and whether any UI suggests unsupported features.
- Preserve the current project visual language unless the user asks for a redesign.

## Ecommerce UI Preferences

- Desktop product grids should prefer 4 columns when the viewport allows it.
- Product cards should use a familiar ecommerce structure: product image on top, product text/details below.
- Desktop product images should feel close to square but slightly shorter, around 15% smaller than a full square at the same card width when it improves balance.
- Product name and price should stay visually grouped; do not push the price far away from the product name.
- Mobile product lists may use compact horizontal cards with image on the left and text on the right when it improves browsing density.
- Do not add unsupported product metadata or actions such as ratings, reviews, wishlist, share, discount UI, or tax UI unless the feature exists or the user asks for it.

## Account And Auth UI

- Login/account pages should expose the primary credential form immediately.
- Avoid large marketing panels or intermediary prompt cards when the user is trying to sign in or manage an account.
- If Google sign-in exists, place it near the primary sign-in/create-account controls and keep the hierarchy clear.

## Supabase

- Use Supabase Auth as the source of user identity.
- User profile data should live in `user_profile` with `id = auth.users.id`.
- Treat RLS policies and Data API grants as a pair; RLS alone is not enough when automatic table exposure is disabled.
- Order totals must be calculated server-side when orders are created; do not trust client-submitted totals.
