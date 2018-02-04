---
layout:   post
title:    "Magento 2 and troubles with email styles"
date:     2018-02-04 00:00:00
author:   "Manuele Menozzi"
tags:     [magento2, wtf]
---
Recently in Webgriffe we migrated a Magento 2 store to a newer production infrastructure managed by us. The new setup was prepared using many best practices recommended by the official Magento’s developer documentation, including Varnish and Magento’s "production" deploy mode.

After the migration was successfully performed we received an issue report by the customer about broken styles in order confirmation email.

We tried to reproduce the problem on our local development environment without success. By comparing email HTML we realized that the one sent by the production infrastructure was missing some inline styles.

After spending the whole afternoon to debug this issue we finally found what was going on.

When Magento renders an email HTML it applies styles from the `email-inline.css` stylesheet. Those styles are applied directly "inline" onto email HTML tags. To do this Magento uses the `pelago/emogrifier` third-party library.

The problem was that the version `0.1.1` of this library, used by all Magento versions less than `2.2.2`, doesn’t handle minified CSS correctly. In "production" mode Magento minifies all the CSSs (including the `email-inline.css`) so its styles are not correctly applied. This also explain why there wasn’t this problem on our local development environments nor on old production infrastructure: those environments didn't use the "production" deploy mode so the `email-inline.css`was never minified.

The solution
------------

The solution was pretty simple. We just forced our Magento store to use an upgraded version of `pelago/emogrifier`. This is possible because the public interface is still the same. We added the following to our root `composer.json` file:

```json
"pelago/emogrifier": "1.2.0 as 0.1.1"
```

This forces Composer to use the version `1.2.0` instead of the `0.1.1`.