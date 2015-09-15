---
layout:   post
title:    "Crazy Magento URL rewrite generation"
date:     2015-09-15 00:00:00
author:   "Manuele Menozzi"
tags:     [magento, wtf]
---

A couple of weeks ago I experienced a Magento URL rewrite behaviour which I wasn't aware of. Considering that I work with Magento since 2010, I decided to write about it.

Pick a clean Magento installation (tested on CE v.1.9.1.1 but I think it's the same for other versions even for EE) and create 2 simple products both with the same name *"Test Product"*. In this way these products should also have the same URL Key *"test-product"*. Be sure that these products are enabled and visibile so relative URL rewrite will be generated. Then, go to URL Rewrite Management admin section and you'll see this:

![image](/img/posts/2015-09-15-crazy-magento-url-rewrite-generation/img1.png)

Ok, that's normal: 2 products 2 related URL rewrites. Now simply execute URL Rewrite reindex process and check URL Rewrite Management again, you'll see this:

![image](/img/posts/2015-09-15-crazy-magento-url-rewrite-generation/img2.png)

WTF?!? The product with ID 2 now has changed the canonical URL from test-product-2.html to test-product-3.html (test-product-2.html now will generate a 301 redirect to test-product-3.html). Let's try to repeat reindex process again, you'll see:

![image](/img/posts/2015-09-15-crazy-magento-url-rewrite-generation/img3.png)

Oh-oh... Now the product with ID 2 has "test-product-4.html" as canonical URL! Again, "test-product-2.html" and "test-product-3.html" are now 301 redirects to "test-product-4.html".

Yes, it's true: Magento, for products with the same URL key, keeps generating URL rewrites again and again as an effect of URL rewrite reindex process.

This behaviour is described in this answer by [Matthias Zeis](https://twitter.com/mzeis) on Magento Stack Exchange: [http://magento.stackexchange.com/questions/18186/understanding-catalog-url-rewrite-indexer/18329#18329](http://magento.stackexchange.com/questions/18186/understanding-catalog-url-rewrite-indexer/18329#18329).

On the same thread there is a code solution to this problem which involves patching the core by changing the `Mage_Catalog_Model_Url` class.
At method `getProductRequestPath`, around line 809, remove the `$product->getUrlKey() == ''` check. So this:

    /**
     * Get unique product request path
     *
     * @param   Varien_Object $product
     * @param   Varien_Object $category
     * @return  string
     */
    public function getProductRequestPath($product, $category)
    {
        // [...]

        /**
         * Check if existing request past can be used
         */
        if ($product->getUrlKey() == '' && !empty($requestPath)
            && strpos($existingRequestPath, $requestPath) === 0
        ) {
            $existingRequestPath = preg_replace(
                '/^' . preg_quote($requestPath, '/') . '/', '', $existingRequestPath
            );
            if (preg_match('#^-([0-9]+)$#i', $existingRequestPath)) {
                return $this->_rewrites[$idPath]->getRequestPath();
            }
        }

        // [...]
    }
     
Has to be changed into this:

	/**
     * Get unique product request path
     *
     * @param   Varien_Object $product
     * @param   Varien_Object $category
     * @return  string
     */
    public function getProductRequestPath($product, $category)
    {
    	// [...]
    	
    	/**
         * Check if existing request past can be used
         */
        if (!empty($requestPath)
            && strpos($existingRequestPath, $requestPath) === 0
        ) {
            $existingRequestPath = preg_replace(
                '/^' . preg_quote($requestPath, '/') . '/', '', $existingRequestPath
            );
            if (preg_match('#^-([0-9]+)$#i', $existingRequestPath)) {
                return $this->_rewrites[$idPath]->getRequestPath();
            }
        }
            
        // [...]
    }

This solution works but I think that is better to not change the core, even with a monkey patch. If possible try to have different URL keys for all products so you don't need this.
