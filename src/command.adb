with Config; use Config;

package body Command is

   ---------------------------
   -- Create_Simple_Command --
   ---------------------------

   function Create_Simple_Command
     (On_Period, Off_Period : Period;
      Note : Note_T) return Note_Generator_Access
   is
   begin
      return new Simple_Command'(Note              => Note,
                                 Current_Sample_Nb => <>,
                                 Memo_Signal       => <>,
                                 On_Period         => On_Period,
                                 Off_Period        => Off_Period,
                                 Current_P         => 0);
   end Create_Simple_Command;

   -----------------------
   -- Next_Message_Impl --
   -----------------------

   overriding function Next_Message_Impl
     (Self : in out Simple_Command) return Note_Signal
   is
   begin
      Self.Current_P := Self.Current_P + 1;
      if Self.Current_P = Self.On_Period then
         return Note_Signal'(Kind => On, Note => Self.Note);
      elsif Self.Current_P = Self.Off_Period then
         return Note_Signal'(Kind => Off, Note => <>);
      else
         return Note_Signal'(Kind => No_Signal, Note => <>);
      end if;
   end Next_Message_Impl;

   ----------------------
   -- Create_Sequencer --
   ----------------------

   function Create_Sequencer
     (Nb_Steps, BPM : Natural;
      Measures : Natural := 1) return access Simple_Sequencer
   is
      Ret : constant access Simple_Sequencer :=
        new Simple_Sequencer'
          (BPM => BPM,
           Nb_Steps => Nb_Steps * Measures,
           Interval => Period
             ((BPM * Natural (SAMPLE_RATE)) / 60 / Nb_Steps),
           others => <>);
   begin
      return Ret;
   end Create_Sequencer;

   -----------------------
   -- Next_Message_Impl --
   -----------------------

   overriding function Next_Message
     (Self : in out Simple_Sequencer) return Note_Signal
   is
      Cur_Note : constant Sequencer_Note :=
        Self.Notes ((Natural (Sample_Nb / Self.Interval)
                    mod Self.Nb_Steps) + 1);
      Current_P : constant Period := Sample_Nb mod Self.Interval;
   begin
      return Res : Note_Signal do
         Res.Kind := No_Signal;

         if Cur_Note.Note /= No_Note then
            if Current_P = Cur_Note.Duration then
               Res.Kind := Off;
            elsif Current_P = 1 then
               Res.Kind := On;
               Res.Note := Cur_Note.Note;
            end if;
         end if;

      end return;

   end Next_Message;

end Command;
