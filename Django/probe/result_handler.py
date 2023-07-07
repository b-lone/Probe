import json
from django.http import JsonResponse
from .models import *

def convert_result_to_json(model):
    result_dict = {
        'id': model.id,
        'state': model.state,
        'use_montage': model.use_montage,
        'montage_ability': model.montage_ability,
        'montage_ability_flag': model.montage_ability_flag,
        'start_memory': model.start_memory,
        'end_memory': model.end_memory,
        'max_memory': model.max_memory,
        'duration': model.duration,
        'error_msg': model.error_msg,
        'file_path': model.file_path,
        'created_at': model.created_at,
        'last_modified': model.last_modified,
        'template_id': model.template.id,
        'task_id': model.task.id,
    }
    return result_dict


def result(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            model = Result()

            state = data.get('state')
            if state is not None:
                model.state = state

            use_montage = data.get('use_montage')
            if use_montage is not None:
                model.use_montage = use_montage

            montage_ability = data.get('montage_ability')
            if montage_ability is not None:
                model.montage_ability = montage_ability

            montage_ability_flag = data.get('montage_ability_flag')
            if montage_ability_flag:
                model.montage_ability_flag = montage_ability_flag

            start_memory = data.get('start_memory')
            if start_memory is not None:
                model.start_memory = start_memory

            end_memory = data.get('end_memory')
            if end_memory is not None:
                model.end_memory = end_memory

            max_memory = data.get('max_memory')
            if max_memory is not None:
                model.max_memory = max_memory

            duration = data.get('duration')
            if duration is not None:
                model.duration = duration

            error_msg = data.get('error_msg')
            if error_msg:
                model.error_msg = error_msg

            file_path = data.get('file_path')
            if file_path:
                model.file_path = file_path

            model.save()

            template_id = data.get('template_id')
            if template_id is not None:
                try:
                    template = Template.objects.get(id=template_id)
                    model.template = template
                    model.save()
                except Template.DoesNotExist:
                    pass

            task_id = data.get('task_id')
            if task_id is not None:
                try:
                    task = Template.objects.get(id=task_id)
                    model.task = task
                    model.save()
                except Template.DoesNotExist:
                    pass

            return JsonResponse(convert_result_to_json(model), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'PUT':
        try:
            data = json.loads(request.body)
            id = data['id']

            model = Task.objects.get(id=id)
            
            state = data.get('state')
            if state is not None:
                model.state = state

            use_montage = data.get('use_montage')
            if use_montage is not None:
                model.use_montage = use_montage

            montage_ability = data.get('montage_ability')
            if montage_ability is not None:
                model.montage_ability = montage_ability

            montage_ability_flag = data.get('montage_ability_flag')
            if montage_ability_flag:
                model.montage_ability_flag = montage_ability_flag

            start_memory = data.get('start_memory')
            if start_memory is not None:
                model.start_memory = start_memory

            end_memory = data.get('end_memory')
            if end_memory is not None:
                model.end_memory = end_memory

            max_memory = data.get('max_memory')
            if max_memory is not None:
                model.max_memory = max_memory

            duration = data.get('duration')
            if duration is not None:
                model.duration = duration

            error_msg = data.get('error_msg')
            if error_msg:
                model.error_msg = error_msg

            file_path = data.get('file_path')
            if file_path:
                model.file_path = file_path

            model.save()
    
            template_id = data.get('template_id')
            if template_id is not None:
                try:
                    template = Template.objects.get(id=template_id)
                    model.template = template
                    model.save()
                except Template.DoesNotExist:
                    pass

            task_id = data.get('task_id')
            if task_id is not None:
                try:
                    task = Template.objects.get(id=task_id)
                    model.task = task
                    model.save()
                except Template.DoesNotExist:
                    pass

            return JsonResponse(convert_result_to_json(model), safe=False)
        
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Result.DoesNotExist:
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
        
        return JsonResponse(convert_result_to_json(model))
    
    elif request.method == 'DELETE':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = Result.objects.get(id=id)
        except Result.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        model.delete()
        
        return JsonResponse({'message': 'Model deleted successfully'})
    
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)

    
def results(request):
    if request.method == 'GET':
        models = Result.objects.all()
        json_list = []
        for model in models:
            json_list.append(convert_result_to_json(model))
        return JsonResponse(json_list, safe=False)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)