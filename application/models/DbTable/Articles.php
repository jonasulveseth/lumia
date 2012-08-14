<?php

class Application_Model_DbTable_Articles extends Zend_Db_Table_Abstract
{

    protected $_name = 'articles';

     /**
     *
     * @var self::instance = new self() 
     */
    
    public static function getAllArticles($limit)
    {
        $instance = new self();
        $articles = $instance->fetchAll(null,$limit);
        return $articles;
   
    }
    
    
    /**
     *
     * @var self::instance = new self() 
     */
    
    public static function getArticleTitle($id)
    {
        $instance = new self();
        $article = $instance->fetchAll(array('id = ?' => $id));
        return $article->title;
        
        
    }
    
     /**
     *
     * @var self::instance = new self() 
     */
    
    public static function getArticleBody($id)
    {
        $instance = new self();
        $article = $instance->fetchAll(array('id = ?' => $id));
        return $article->title;
    }
    


}

