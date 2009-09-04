!----------------------------------------------------------------------------
! This file is part of DALES.
!
! DALES is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! DALES is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
! Copyright 1993-2009 Delft University of Technology, Wageningen University, Utrecht University, KNMI,MPI-M
!----------------------------------------------------------------------------
!
! TODO: Enable 2D and 3D grids
module modstat_nc
    use netcdf
    implicit none
!     integer :: ncid,ttsid,tprid,zid
    logical :: lnetcdf

    integer, save :: timeID=0, ztID=0, zmID=0, xtID=0, xmID=0, ytID=0, ymID=0

contains


  subroutine initstat_nc
    use modglobal, only : kmax,ifnamopt,fname_options,iexpnr
    use modmpi,    only : mpierr,mpi_logical,comm3d,myid
    implicit none

    integer             :: ierr

    namelist/NAMNETCDFSTATS/ &
    lnetcdf

    if(myid==0)then
      open(ifnamopt,file=fname_options,status='old',iostat=ierr)
      read (ifnamopt,NAMNETCDFSTATS,iostat=ierr)
      write(6, NAMNETCDFSTATS)
      close(ifnamopt)
    end if

    call MPI_BCAST(lnetcdf    ,1,MPI_LOGICAL, 0,comm3d,mpierr)
  return
  end subroutine initstat_nc
!
! ----------------------------------------------------------------------
! Subroutine Open_NC: Opens a NetCDF File and identifies starting record
!
subroutine open_nc (fname, ncid,lead,frontrun, n1, n2, n3)
  use modglobal, only : author,version
  implicit none

 integer, intent(inout):: ncid
 integer, intent(out) :: frontrun
 logical, intent(in) :: lead
  integer, optional, intent (in) :: n1, n2, n3
 character (len=40), intent (in) :: fname

 character (len=8):: date
 integer :: iret
 logical :: lopen

    inquire(file=trim(fname),opened=lopen)

  if (.not.lopen) then
    if (.not. lead) frontrun=1
    call date_and_time(date)
    iret = nf90_create(fname,NF90_SHARE,ncid)
    iret = nf90_put_att(ncid,NF90_GLOBAL,'title',fname)
    iret = nf90_put_att(ncid,NF90_GLOBAL,'history','Created on '//date)
    iret = nf90_put_att(ncid, NF90_GLOBAL, 'Source',trim(version))
    iret = nf90_put_att(ncid, NF90_GLOBAL, 'Author',trim(author))
    iret = nf90_put_att(ncid, NF90_GLOBAL, '_FillValue',-999.)
    if (present(n1)) then
      iret = nf90_def_dim(ncID, 'xt', n1, xtID)
      iret = nf90_def_dim(ncID, 'xm', n1, xmID)
    end if
    if (present(n2)) then
      iret = nf90_def_dim(ncID, 'yt', n2, ytID)
      iret = nf90_def_dim(ncID, 'ym', n2, ymID)
    end if
    if (present(n3)) then
      iret = nf90_def_dim(ncID, 'zt', n3, ztID)
      iret = nf90_def_dim(ncID, 'zm', n3, zmID)
    end if
  else
      iret = nf90_redef(ncid)
  end if
  iret = nf90_sync(ncid)

end subroutine open_nc
!
! ----------------------------------------------------------------------
! Subroutine Define_NC: Defines the structure of the nc file (if not
! already open)
!
subroutine define_nc(ncID, nVar, sx)
  implicit none
  integer, intent (in) :: nVar, ncID
  character (len=80), intent (in) :: sx(nVar,4)

  integer, save ::  dim_mttt(4) = 0, dim_tmtt(4) = 0, dim_ttmt(4) = 0, dim_tttt(4) = 0, dim_tt(2)= 0, dim_mt(2)= 0,dim_t0tt(3)=0,dim_m0tt(3)=0,dim_t0mt(3)=0,dim_tt0t(3)=0,dim_mt0t(3)=0,dim_tm0t(3)=0,dim_0ttt(3)=0,dim_0mtt(3)=0,dim_0tmt(3)=0

  integer :: iret, n, VarID
  dim_tt = (/ztId,timeId/)
  dim_mt = (/zmId,timeId/)
  dim_t0tt= (/xtID,ztID,timeId/)! thermo point
  dim_t0mt= (/xtID,zmID,timeId/)! zpoint
  dim_m0tt= (/xmID,ztID,timeId/)! upoint

  dim_tt0t= (/xtID,ytID,timeId/)! thermo point
  dim_tm0t= (/xtID,ymID,timeId/)! vpoint
  dim_mt0t= (/xmID,ytID,timeId/)! upoint

  dim_0ttt= (/ytID,ztID,timeId/)! thermo point
  dim_0tmt= (/ytID,zmID,timeId/)! wpoint
  dim_0mtt= (/ymID,ztID,timeId/)! vpoint

  dim_tttt= (/xtID,ytID,ztID,timeId/)! thermo point
  dim_ttmt= (/xtID,ytID,zmID,timeId/)! zpoint
  dim_mttt= (/xmID,ytID,ztID,timeId/)! upoint
  dim_tmtt= (/xtID,ymID,ztId,timeId/)! ypoint
  do n=1,nVar
    select case(trim(sx(n,4)))
      case ('time')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,timeId,VarID)
      case ('zt')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,ztID ,VarID)
      case ('zm')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,zmID ,VarID)
      case ('xt')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,xtID ,VarID)
      case ('xm')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,xmID ,VarID)
      case ('yt')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,ytID ,VarID)
      case ('ym')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,ymID ,VarID)
      case ('tttt')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,dim_tttt,VarID)
      case ('mttt')
        iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,dim_mttt,VarID)
      case ('tmtt')
          iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,dim_tmtt,VarID)
      case ('ttmt')
          iret=nf90_def_var(ncID,sx(n,1),NF90_FLOAT,dim_ttmt,VarID)
      case default
      print *, 'ABORTING: Bad dimensional information'
      stop
      ! call appl_abort(0)
    end select
    iret=nf90_put_att(ncID,VarID,'longname',sx(n,2))
    iret=nf90_put_att(ncID,VarID,'units',sx(n,3))
  end do
  iret= nf90_enddef(ncID)
  iret= nf90_sync(ncID)
  end subroutine define_nc

  subroutine exitstat_nc(ncid)

   implicit none
   integer, intent(in) :: ncid
   integer status

   status = nf90_close(ncid)
   if (status /= nf90_noerr) call nchandle_error(status)
 end subroutine exitstat_nc


  subroutine writetstat_nc(ncid,nvar,ncname,vars,nrec,lraise)
    implicit none
    integer, intent(in)                      :: ncid,nvar
    integer, intent(inout)                   :: nrec
    real,dimension(nvar),intent(in)          :: vars
    character(*), dimension(:,:),intent(in)  :: ncname
    logical, intent(in)                      :: lraise

    integer :: iret,n,varid
    if(lraise) then
      nrec = nrec+1
    end if
    do n=1,nvar
       iret = nf90_inq_varid(ncid, ncname(n,1), VarID)
       iret = nf90_put_var(ncid, VarID, vars(n), start=(/nrec/))
    end do
    iret = nf90_sync(ncid)

  end subroutine writetstat_nc

  subroutine writestat1D_nc(ncid,nvar,ncname,vars,nrec,lraise,dimmin,dimmax,wrmin,wrmax)
    implicit none
    integer, intent(in)                      :: ncid,nvar,dimmin,dimmax,wrmin,wrmax
    integer, intent(inout)                   :: nrec
    real,dimension(dimmin:dimmax,nvar),intent(in)   :: vars
    character(*), dimension(:,:),intent(in)  :: ncname
    logical, intent(in)                      :: lraise

    integer :: iret,n,varid
    if(lraise) then
      nrec = nrec+1
    end if
    do n=1,nvar
       iret = nf90_inq_varid(ncid, ncname(n,1), VarID)
       iret = nf90_put_var(ncid, VarID, vars(wrmin:wrmax,n), start=(/nrec/))
    end do
    iret = nf90_sync(ncid)

  end subroutine writestat1D_nc
  subroutine writestat2D_nc(ncid,nvar,ncname,vars,nrec,lraise,dim1min,dim1max,wr1min,wr1max,dim2min,dim2max,wr2min,wr2max)
    implicit none
    integer, intent(in)                      :: ncid,nvar,dim1min,dim1max,wr1min,wr1max,dim2min,dim2max,wr2min,wr2max
    integer, intent(inout)                   :: nrec
    real,dimension(dim1min:dim1max,dim2min:dim2max,nvar),intent(in)   :: vars
    character(*), dimension(:,:),intent(in)  :: ncname
    logical, intent(in)                      :: lraise

    integer :: iret,n,varid
    if(lraise) then
      nrec = nrec+1
    end if
    do n=1,nvar
       iret = nf90_inq_varid(ncid, ncname(n,1), VarID)
       iret = nf90_put_var(ncid, VarID, vars(wr1min:wr1max,wr2min:wr2max,n), start=(/nrec/))
    end do
    iret = nf90_sync(ncid)

  end subroutine writestat2D_nc
  subroutine writestat3D_nc(ncid,nvar,ncname,vars,nrec,lraise,dim1min,dim1max,wr1min,wr1max,dim2min,dim2max,wr2min,wr2max,dim3min,dim3max,wr3min,wr3max)
    implicit none
    integer, intent(in)                      :: ncid,nvar,dim1min,dim1max,wr1min,wr1max,dim2min,dim2max,wr2min,wr2max,dim3min,dim3max,wr3min,wr3max
    integer, intent(inout)                   :: nrec
    real,dimension(dim1min:dim1max,dim2min:dim2max,dim3min:dim3max,nvar),intent(in)   :: vars
    character(*), dimension(:,:),intent(in)  :: ncname
    logical, intent(in)                      :: lraise

    integer :: iret,n,varid
    if(lraise) then
      nrec = nrec+1
    end if
    do n=1,nvar
       iret = nf90_inq_varid(ncid, ncname(n,1), VarID)
       iret = nf90_put_var(ncid, VarID, vars(wr1min:wr1max,wr2min:wr2max,wr3min:wr3max,n), start=(/nrec/))
    end do
    iret = nf90_sync(ncid)

  end subroutine writestat3D_nc

  subroutine ncinfo(out,in1,in2,in3,in4)

    implicit none
    character(*), dimension(4),intent(out) ::out
    character(*), intent(in) ::in1,in2,in3,in4
    out(1) = in1
    out(2) = in2
    out(3) = in3
    out(4) = in4
  end subroutine ncinfo

  subroutine nchandle_error(status)
    use netcdf
    implicit none

    integer, intent(in) :: status

    if(status /= nf90_noerr) then
      print *, trim(nf90_strerror(status))
      stop "Stopped"
    end if

  end subroutine nchandle_error

end module modstat_nc