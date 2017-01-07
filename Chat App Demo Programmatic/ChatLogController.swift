//
//  ChatLogController.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2017-01-04.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import Firebase

//**2 WAYS OF MOVING THE INPUT CONTAINER VIEW VIA MOVING NOTIFICATIONS AND inputAccessoryView...pick one!

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
    let cellId = "cellId"
    
    //to be called by MessageController.showChatControllerForUser()
    //when set, it will set the ChatLogController nav bar title to the name of the user
    var user: User? {
        
        didSet{
            
            navigationItem.title = user?.name
            
            observeMessages()
            
        }
        
    }
    
    //messages array of type Message to store the messages
    var messages = [Message]()
    
    lazy var inputTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Message..."
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        return tf
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        //need to register a cell for collectionView
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        //putting some room between the first cell at top and the nav bar, 8 pixels and 50 above the input area and 8 padding between the input and the last bubble
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //have to change the scrollIndicatorInset everytime you change the contentInset to match the scrolling
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        //setupInputComponents()
        
        //setupKeyboardObservers()
        
        collectionView?.keyboardDismissMode = .interactive
        
    }
    //lazy var to access self
    //used by inputAccessoryView and canBecomeFirstResponder to make the inputContainer and keyboard interactive by swipes
    lazy var inputContainerView: UIView = {
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = .white
        
        //type: .system to give the button a downstate
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        containerView.addSubview(self.inputTextField)
        
        //ios9 constraints x, y, w, h
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        //ios9 constraints x, y, w, h
        self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = .lightGray
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        //ios9 constraints x, y, w, h
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        
        return containerView
        
    }()
    
    override var inputAccessoryView: UIView? {
        
        get{
            return inputContainerView
        }
        
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    //2 methods needed by collectionViewController
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        //individualizing the members of the array for each cell
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        //modifying the bubbleView's width
        cell.bubbleWidthAnchor?.constant = estimateFrameForTex(text: message.text!).width + 32
        
        return cell
    }
    
    //cleaning up the cellForItemAt()
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        guard let profileImageUrl = self.user?.profileImageUrl else {return}
        cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        
        //set up both colors in here and else because when cells are reused they may not reset
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            //outgoing message             
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            //playing with the bubbleView anchors to allign it accordingly depending on sender
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            
        }else{
            //incoming message
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            //playing with the bubbleView anchors to allign it accordingly depending on sender
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            
        }
        
    }
    
    //this is called everytime you rotate device or go to landscape mode...this will push the chat to the sides instead of width staying same as the portrait width
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout() //fix we get pretty easily if we use ios9 constraints instead of CGFrames or CGRect
    }
    
    //comforms to UICollectionViewDelegateFlowLayout....extends the cells accross the width with a height of 80
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        //get the estimated height somehow
        if let text = messages[indexPath.item].text {
            //+20 so the top and bottom dont get cut off...thats how textView works
            height = estimateFrameForTex(text: text).height + 20
            
        }
        //setting the width to this instead of view.frame.width because for some odd reason, inputAccessoryView mucked things up...so this is a sure way of getting the whole width of the device screen.
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    //getting the estimated height of the cells so it expands dependending on how long the text is.
    private func estimateFrameForTex(text: String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        //ep. 13 9m 02s...basically binding the text in a invisible square around it and thats what we base our cells height and width
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func setupKeyboardObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboarWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        //get the frame of keyboard to figure out where to move the input containerView
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        //get the keyboardDuration so we can animate
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        //after you modify the constraint, to animate just call self.view.layoutIfNeeded()
        containerViewBottomAnchor?.constant = -keyboardFrame.height
        UIView.animate(withDuration: keyboardDuration!) { 
            self.view.layoutIfNeeded()
        }
        
    }
    
    func keyboarWillHide(notification: NSNotification) {
        
        //get the keyboardDuration so we can animate
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        //after you modify the constraint, to animate just call self.view.layoutIfNeeded()
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    //HAVE TO REMOVE ANY NOTIFICATIONS OR ELSE THERE WILL BE A MEMORY LEAK. IDEALLY REMOVE THEM WHEN VIEW DISAPPEARS
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    
    func observeMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else {return}
        //observe all the message id under the current uid in user-messages node first
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            //now we get the messages that has the Id that we fetched above
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in

                //assingning snapshot.value to a dictionary type variable
                guard let dictionary = snapshot.value as? [String: AnyObject] else {return}
                //reference to Message()
                let message = Message()
                //assigning the value of dictionary into message var to turn it into type Message()
                //potential of crashing if class keys dont match
                //there is a solution here somewhere.
                message.setValuesForKeys(dictionary)
                
                self.messages.append(message)
                    
                    //bringing back to main thread before calling reloadData else CRASH! cannot reload data in background
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
    }
    
    //reference to containerView Y constraints
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    //adding the message input components into the view
    func setupInputComponents() {
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        //its default is transparent so you will see the cells behind it. put it to .white to debug it
        containerView.backgroundColor = .white
        
        view.addSubview(containerView)
        
        //ios9 constraints x, y, w, h
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        
        
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //type: .system to give the button a downstate
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        containerView.addSubview(inputTextField)
        
        //ios9 constraints x, y, w, h
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        //ios9 constraints x, y, w, h
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = .lightGray
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        //ios9 constraints x, y, w, h
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
    }
    
    func handleSend() {
        
        let ref = FIRDatabase.database().reference().child("messages")
        //generates a child with a unique key in every entry. so we dont replace the previous entries
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()?.currentUser?.uid
        let timeStamp: NSNumber = Int(NSDate().timeIntervalSince1970) as NSNumber
        let values = ["text": inputTextField.text ?? "", "toId": toId, "fromId": fromId ?? "", "timeStamp": timeStamp] as [String : Any]
        //childRef.updateChildValues(values)
        
        //restructuring the messages by fanning so we can group them by user id
        //FANNING OUT IS A GREAT COST SAVER BECAUSE YOURE NOT OBSERVING THE WHOLE LIST OF MILLIONS OF MESSAGES BUT ONLY THE ONES WITH THE ITS REFERENCE UNDER THE CURRENT USER ID.
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(error!)
            }
            
            //saving a reference to the messages under the current user's id
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId!).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            //saving the same reference to the messages under the recipient's user's id
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId!)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
            
        }
        
        inputTextField.text = nil
    }
    
    //use enter to send
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
}
