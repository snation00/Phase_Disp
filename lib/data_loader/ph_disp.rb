# encoding: utf-8

module DataLoader
  class PhDisp
    include DataMapper::Resource
    storage_names[:default] = 'ph_disps'

    # t9t10 --> the circuit that was scanned...in the case, all will be t9t10 (a string)
    # high --> laser pulse energy (also a string)
    # 1012 --> the pixel number...when in the scan the file was made (int)
    # avg1 --> the scan number as: avg#. In this case it's always integers 1-5.

    property :id,           Serial
    property :circuit,      String, :required => true, :index => true
    property :node,         String
    property :energy,       String
    property :start_time,   String, :required => true
    property :cycle_end,    Float, :required => true
    property :displ_p,      Float 
    property :displ_n,      Float 
  end
end
