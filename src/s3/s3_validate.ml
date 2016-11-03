(**************************************************************************)
(*  LibreS3 server                                                        *)
(*  Copyright (C) 2012-2016 Skylable Ltd. <info-copyright@skylable.com>   *)
(*                                                                        *)
(*  This program is free software; you can redistribute it and/or modify  *)
(*  it under the terms of the GNU General Public License version 2 as     *)
(*  published by the Free Software Foundation.                            *)
(*                                                                        *)
(*  This program is distributed in the hope that it will be useful,       *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU General Public License for more details.                          *)
(*                                                                        *)
(*  You should have received a copy of the GNU General Public License     *)
(*  along with this program; if not, write to the Free Software           *)
(*  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,            *)
(*  MA 02110-1301 USA.                                                    *)
(*                                                                        *)
(*  Special exception for linking this software with OpenSSL:             *)
(*                                                                        *)
(*  In addition, as a special exception, Skylable Ltd. gives permission   *)
(*  to link the code of this program with the OpenSSL library and         *)
(*  distribute linked combinations including the two. You must obey the   *)
(*  GNU General Public License in all respects for all of the code used   *)
(*  other than OpenSSL. You may extend this exception to your version     *)
(*  of the program, but you are not obligated to do so. If you do not     *)
(*  wish to do so, delete this exception statement from your version.     *)
(**************************************************************************)

open Astring
open Rresult
type bucket_name = string

let is_dns_compliant name =
  failwith "TODO"

let expect_range ?(min=min_int) ?(max=max_int) msg actual =
  if actual < min then R.error_msgf "%s invalid: %d < %d" msg actual min
  else if actual > max then R.error_msgf "%s invalid: %d > %d" msg actual max
  else Ok ()

let is_bad_classic = function
| 'A' .. 'Z' | 'a' .. 'z' | '0'..'9' | '.' | '-' | '_' -> false
| _ -> true

let validate_string ~msg is_bad str =
  match String.find is_bad str with
  | None -> Ok ()
  | Some i -> R.error_msgf "%s contains invalid character %c" msg str.[i]

let is_classic_compliant name = R.(
    expect_range ~max:255 "Bucket name length" (String.length name) >>= fun () ->
    validate_string ~msg:"Bucket name" is_bad_classic name >>= fun () ->
    Ok name)

let is_bad_dns = function
| 'a' .. 'z' | '0' .. '9' | '-' -> false
| _ -> true

let validate_label accum label =
  R.(accum >>= fun () ->
     validate_string ~msg:"Bucket name" is_bad_dns label >>= fun () ->
     if String.length label = 0 then R.error_msgf ".. not allowed in bucket name"
     else match label.[0], label.[String.length label-1] with
     | ('a'..'z'|'0'..'9'), ('a'..'z'|'0'..'9') -> Ok () 
     | _ -> R.error_msgf "Bucket name label %S invalid start/end character" label)

let is_dns_compliant name =
  expect_range ~min:3 ~max:63 "Bucket name length" (String.length name) >>= fun () ->
  String.cuts ~sep:"." name |>
  List.fold_left validate_label (Ok ()) >>= fun () ->
  Ok name