---
layout:     post
title:      "Session handling while testing Magento with Ecomdev_PHPUnit"
date:       2015-07-21 12:00:00
author:     "Manuele Menozzi"
tags: [magento, ecomdev-phpunit, tdd]
---

When testing Magento with Ecomdev_PHPUnit the following error could occur:

    Exception: Warning: session_start(): Cannot send session cookie - headers already sent by (output started at [...]/vendor/phpunit/phpunit/src/Util/Printer.php:172)  in [...]/app/code/core/Mage/Core/Model/Session/Abstract/Varien.php on line 123

This error happens because somewhere in your tested code there is an itialization to a Magento's session singleton/model that casues a `session_start` which in turn needs to set the related cookie/session header. The error is thrown because the output has already started due to PHPUnit initial output.

The architecture of these Magento models sucks and there is no separation between domain session logic and PHP `session_*` functions but fortunately we can mock session calls through Ecomdev_PHPUnit.

    protected function setUp()
    {
        parent::setUp();
        $coreSessionMock = $this
            ->getMockBuilder('Mage_Catalog_Model_Session')
            ->setMethods(array('start'))
            ->getMock();
        $this->replaceByMock('singleton', 'core/session', $coreSessionMock);
    }

Note that this completely mock all calls to `Mage_Catalog_Model_Session::start()` and avoid the error shown above but should be tweaked accordling to your specific needs.

More on this topic can be found on the related [GitHub issue](https://github.com/EcomDev/EcomDev_PHPUnit/issues/206) with some workaround solutions.
