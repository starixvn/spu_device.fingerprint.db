ALTER TABLE `FPS_FingerPrint`.`ClientTransaction` 
ADD UNIQUE INDEX `UX_ClientTransaction_SessionKey` (`SessionKey` ASC);