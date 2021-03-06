;+
; procedure to subset raster using shapefile
;
; :Arguments:
;   i_fn: input filename
;   o_fn: target filename
;-
pro subsetByShp, i_fn, o_fn
  compile_opt idl2, hidden
  log, 'subset by shapefile [I]: ', i_fn

  i_shp = (!obj.flag)[0]

  raster = !e.OpenRaster(i_fn)
  shp = !e.OpenVector(i_shp)

  ;get the boundry of shapefile
  oShp = IDLffShape(i_shp)
  entity = oShp.GetEntity(0, /ATTRIBUTES)
  verts = *(entity.VERTICES)

  raster_cs = raster.SpatialRef
  shp_cs = shp.Coord_Sys
  shp_cs_str = shp_cs.Coord_Sys_Str

  ;convert the boundry to the raster's map
  if STRCMP(shp_cs_str, 'GEOGCS', 6) then begin
    shp_cs.ConvertLonLatToLonLat, verts[0, *], $
      verts[1, *], lon1, lat1, raster_cs
    raster_cs.ConvertLonLatToMap, lon1, lat1, mapx, mapy
  endif else if STRCMP(shp_cs_str, 'PROJCS', 6) then begin
    shp_cs.ConvertMapToMap, verts[0, *], $
      verts[1, *], mapx, mapy, raster_cs
  endif else begin
    log, 'current shapefile not supported'
    RETURN
  endelse

  ;get the extent of the shapefile inside the raster
  raster_sr = raster.SpatialRef
  raster_sr.ConvertMapToFile, mapx, mapy, filex, filey
  filex = filex[WHERE(filex gt 0 and filex le raster.nsamples)]
  filey = filey[WHERE(filey gt 0 and filey le raster.nlines)]
  max_x = ROUND(MAX(filex))
  min_x = ROUND(MIN(filex))
  max_y = ROUND(MAX(filey))
  min_y = ROUND(MIN(filey))

  ;subset and close
  subRaster = raster.Subset(SUB = [min_x,min_y,max_x,max_y])
  subRaster.Export, o_fn, 'envi'
  OBJ_DESTROY, oShp
  subRaster.Close
  raster.Close
  shp.Close
  log, 'subset by shapefile [O]: ', o_fn
end