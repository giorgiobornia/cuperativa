#file: modal_msg_box.rb

module ModalMessageBox
  
  ##
  # Modal message box with question yes / no
  def modal_yesnoquestion_box(caption, text)
    if FXMessageBox.question(self, MBOX_YES_NO, caption, text) == MBOX_CLICKED_YES
      update_dsp
      return true
    end
    update_dsp
    return false
  end
  
  ##
  # Critical error. Show a dialogbox and exit application
  def mycritical_error(str)
    FXMessageBox.error(self, MBOX_OK, "Errore applicazione", str)
    exit
  end

  
  ##
  # Modal message box for error message
  def modal_errormessage_box(caption, text)
    FXMessageBox.error(self, MBOX_OK, caption, text)
  end
  
  ##
  # Modal message box for information message
  def modal_information_box(caption, text)
    FXMessageBox.information(self, MBOX_OK, caption, text)
  end
  
end