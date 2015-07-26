---
layout:     post
title:      "Config area in Magento Ecomdev_PHPUnit tests"
date:       2015-07-23 20:19:00
author:     "Manuele Menozzi"
tags: [magento, ecomdev-phpunit, tdd]
---

When testing **Magento** with **Ecomdev_PHPUnit**, it should be constantly kept in mind that by default it loads only the `global` area. If you want to test a behavior which requires configuration from others area, you have to load it explicitly.

For example if you want to test an observer of the event `catalog_product_collection_load_before` defined in `frontend` configuration area, you have to load `frontend` area at the beginning of your test. For example:

	public function testMyFrontendObserver()
	{
		Mage::app()->loadArea(Mage_Core_Model_App_Area::AREA_FRONTEND);
		$productCollection = Mage::getModel('catalog/product')
			->getCollection()
			->load();
		// ...test observer behavior		
	}
	
Without the line `Mage::app()->loadArea(Mage_Core_Model_App_Area::AREA_FRONTEND);` the observer will not be triggered.

Note that in this way `frontend` area remains loaded even for tests which come after the `testMyFrontendObserver`. This happens because the `Mage_Core_Model_Config` instance remains stored in memory with `frontend` area loaded. Obviously, this breakes test isolation in your test suite because you could have tests that come after `testMyFrontendObserver` which will fail due to `frontend` area loaded in configuration.

To solve this problem you have to remove `frontend` area from configuration after test execution, for example using the `tearDown` method:

	public function tearDown()
	{
		Mage::app()->removeEventArea(Mage_Core_Model_App_Area::AREA_FRONTEND);
	}

Update: thanks to [@fschmelger](https://twitter.com/fschmengler), I must point out that in controllers tests, proper area is loaded automatically by Ecomdev_PHPUnit, so it's not needed explicit `loadArea` call stated above.
