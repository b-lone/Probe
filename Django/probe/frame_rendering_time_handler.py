import json
from django.http import JsonResponse
from .models import *

def convert_frame_rendering_time_to_json(model):
    dict = {
        'id': model.id,
        'position': model.position,
        'rendering_time': model.rendering_time,
        'result_id': model.result.id,
    }
    return dict

def frame_rendering_time(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body.decode('utf-8'))

            model = FrameRenderingTime()

            position = data['position']
            if position is not None:
                model.position = position

            rendering_time = data['rendering_time']
            if rendering_time is not None:
                model.rendering_time = rendering_time
            
            model.save()

            result_id = data.get('result_id')
            if result_id is not None:
                try:
                    result = Result.objects.get(id=result_id)
                    model.result = result
                    model.save()
                except Result.DoesNotExist:
                    pass
                
            return JsonResponse(convert_frame_rendering_time_to_json(model), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'PUT':
        try:
            data = json.loads(request.body)
            id = data['id']

            model = FrameRenderingTime.objects.get(id=id)
            
            position = data.get('position')
            if position:
                model.position = position

            rendering_time = data['rendering_time']
            if rendering_time is not None:
                model.rendering_time = rendering_time

            model.save()

            result_id = data.get('result_id')
            if result_id is not None:
                try:
                    result = Result.objects.get(id=result_id)
                    model.result = result
                    model.save()
                except Result.DoesNotExist:
                    pass
    
            return JsonResponse(convert_frame_rendering_time_to_json(model), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except FrameRenderingTime.DoesNotExist:
                return JsonResponse({'error': 'Model not found'}, status=404)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'GET':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = Result.objects.get(id=id)
        except Result.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        return JsonResponse(convert_frame_rendering_time_to_json(model))
    
    elif request.method == 'DELETE':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = FrameRenderingTime.objects.get(id=id)
        except FrameRenderingTime.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        model.delete()

        return JsonResponse({'message': 'Model deleted successfully'})
    
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)

    
def frame_rendering_times(request):
    if request.method == 'GET':
        models = FrameRenderingTime.objects.all()
        json_list = []
        for model in models:
            json_list.append(convert_frame_rendering_time_to_json(model))
        return JsonResponse(json_list, safe=False)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)