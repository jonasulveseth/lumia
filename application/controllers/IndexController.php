<?php

class IndexController extends Zend_Controller_Action
{

    public function init()
    {

    }

    public function indexAction()
    {
        $articles = Application_Model_DbTable_Articles::getAllArticles('3');
        $this->view->articles = $articles; 
    }


}

