---
layout:   post
title:    "Magento WTF: memory limit check in Gd2 image adapter"
date:     2015-07-30 00:00:00
author:   "Manuele Menozzi"
tags:     [magento, wtf]
---

A few days ago I was coding on a catalog **images** import component in Magento. The import component is based on [AvS_FastSimpleImport](http://avstudnitz.github.io/AvS_FastSimpleImport/) and invoked through a Magento's shell script. As you may know, AvS_FastSimpleImport is a wrapper for Magento's native Import/Export so using it will cause to use Magento core classes.

When the work was done I launched the import shell script with some test images in the `media/import` directory and I got the following error:

	Uncaught exception 'Varien_Exception' with message 'Memory limit has been reached.'

My first thought was: "Uhm... That's weird... My shell script sets `memory_limit` to `-1` (which means no limit)".

In fact, usually, my import shell script overrides the `_applyPhpVariables` method and forces `memory_limit` and `max_execution_time` to fit long/expensive execution needs:

	// class MyShellScript extends Mage_Shell_Abstract
	
	protected function _applyPhpVariables()
    {
        parent::_applyPhpVariables();
        @ini_set('memory_limit', '-1');
        @ini_set('max_execution_time', '36000');
    }

So, I searched for the exception and I found that during the image import Magento calls the following method for every image to import:
	
	/**
     * Opens image file.
     *
     * @param string $filename
     * @throws Varien_Exception
     */
    public function open($filename)
    {
        $this->_fileName = $filename;
        $this->getMimeType();
        $this->_getFileAttributes();
        if ($this->_isMemoryLimitReached()) {
            throw new Varien_Exception('Memory limit has been reached.');
        }
        $this->_imageHandler = call_user_func($this->_getCallback('create'), $this->_fileName);
    }
    
This code is in the class `Varien_Image_Adapter_Gd2`. Let's look at the implementation of method `_isMemoryLimitReached`:

	/**
     * Checks whether memory limit is reached.
     *
     * @return bool
     */
    protected function _isMemoryLimitReached()
    {
        $limit = $this->_convertToByte(ini_get('memory_limit'));
        $size = getimagesize($this->_fileName);
        $requiredMemory = $size[0] * $size[1] * 3;
        return (memory_get_usage(true) + $requiredMemory) > $limit;
    }
    
What the F**k!?!?! Note that, as said above `memory_limit` is `-1` so `ini_get('memory_limit')` converted to byte will be `-1` so every memory usage value will always be greater than `-1`.

Conclusion: Magento's image import will always fail if invoked with unlimited memory (which makes sense in a CLI shell script).

To solve the problem I replaced the `@ini_set('memory_limit', '-1')` with `@ini_set('memory_limit', '512M')`. It would have been enough to simply remove `@ini_set('memory_limit', '-1')` because the parent `_applyPhpVariables` applies the `memory_limit` found in the `.htaccess` file but I don't want that memory limit of a PHP shell script is controlled by a configuration file for Apache.

Pay also attention that the suffix `G` can't be used in `memory_limit` to indicate gigabytes. This is because the method `_convertToByte` of that class is implemented as follows:

	/**
     * Converts memory value (e.g. 64M, 129KB) to bytes.
     * Case insensitive value might be used.
     *
     * @param string $memoryValue
     * @return int
     */
    protected function _convertToByte($memoryValue)
    {
        if (stripos($memoryValue, 'M') !== false) {
            return (int)$memoryValue * 1024 * 1024;
        } elseif (stripos($memoryValue, 'KB') !== false) {
            return (int)$memoryValue * 1024;
        }
        return (int)$memoryValue;
    }
    
As you can see the `G` suffix it's not taken into consideration.

	
