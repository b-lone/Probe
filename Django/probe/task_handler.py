import json
from django.http import JsonResponse
from .models import *

def convert_task_to_json(model):
    dict = {
        'id': model.id,
        'sum': model.sum,
    }
    return dict

def task(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body.decode('utf-8'))
            sum = data['sum']

            model = Task(sum=sum)
            model.save()
                
            return JsonResponse(convert_task_to_json(model), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'PUT':
        try:
            data = json.loads(request.body)
            id = data['id']

            model = Task.objects.get(id=id)
            
            sum = data.get('sum')
            if sum:
                model.sum = sum

            model.save()
    
            return JsonResponse(convert_task_to_json(test_case), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Task.DoesNotExist:
                return JsonResponse({'error': 'Model not found'}, status=404)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'GET':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = Task.objects.get(id=id)
        except Task.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        return JsonResponse(convert_task_to_json(model))
    
    elif request.method == 'DELETE':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = Task.objects.get(id=id)
        except Task.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        model.delete()
        
        return JsonResponse({'message': 'Model deleted successfully'})
    
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)

    
def tasks(request):
    if request.method == 'GET':
        models = Task.objects.all()
        json_list = []
        for model in models:
            json_list.append(convert_task_to_json(model))
        return JsonResponse(json_list, safe=False)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)