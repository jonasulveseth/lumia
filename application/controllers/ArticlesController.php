<?php

class ArticlesController extends Zend_Controller_Action
{
    public function indexAction()
    {
        
    }
    
    public function newAction()
    {
        $form = new Application_Form_NewArticle();
        $this->view->form = $form;
        
        $request = $this->getRequest();
        if($request->isPost())
        {
            if($form->isValid($request->getPost()))
            {
                $articleModel = new Application_Model_DbTable_Articles();
                $article = $articleModel->createRow();
                $article->setFromArray($form->getValues());
                $article->save();
            }
        }
        
    }
    
    public function listAction()
    {
        $articlesModel = new Application_Model_DbTable_Articles();
        $articles = $articlesModel->fetchAll();
        Zend_Debug::dump($articles);
    }
}

