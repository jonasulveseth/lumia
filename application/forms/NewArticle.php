<?php
class Application_Form_NewArticle extends Zend_Form
{
    public function init()
    {
        /**
         *Name 
         */
        $name = $this->createElement('text', 'title');
        $name->setLabel('Title');
        $name->setRequired();
        
        $this->addElement($name);
        
        /**
         *Body 
         */
        $body = $this->createElement('textarea', 'body');
        $body->setLabel('Text');
        $body->setRequired();
        
        $this->addElement($body);
        
        /**
         *Submit 
         */
        $submit = $this->createElement('submit', 'button');
        $submit->setLabel('submit');
        $this->addElement($submit);    }
}
