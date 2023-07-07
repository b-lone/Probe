import json
from django.http import JsonResponse
from .models import *

def convert_testcase_to_json(model):
    template_ids = model.templates.values_list('id', flat=True)
    dict = {
        'id': model.id,
        'name': model.name,
        'created_at': model.created_at,
        'last_modified': model.last_modified,
        'template_ids': list(template_ids),
    }
    return dict

def testcase(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body.decode('utf-8'))

            model = TestCase()

            name = data['name']
            if name is not None:
                model.name = name

            model.save()

            template_ids = data.get('template_ids', [])
            for template_id in template_ids:
                try:
                    template = Template.objects.get(id=template_id)
                except Template.DoesNotExist:
                    template = Template(id=template_id)
                    template.save()
                model.templates.add(template)
                
            return JsonResponse(convert_testcase_to_json(model), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
    
    elif request.method == 'PUT':
        try:
            data = json.loads(request.body)
            id = data['id']
            
            model = TestCase.objects.get(id=id)
            
            name = data.get('name')
            template_ids = data.get('template_ids', [])
    
            if name:
                model.name = name
            if template_ids:
                model.templates.clear()
                for template_id in template_ids:
                    try:
                        template = Template.objects.get(id=template_id)
                    except Template.DoesNotExist:
                        template = Template(id=template_id)
                        template.save()
                    model.templates.add(template)
    
            model.save()
    
            return JsonResponse(convert_testcase_to_json(model), safe=False)
        except KeyError:
            return JsonResponse({'message': 'Invalid JSON format: Missing required field'}, status=400)
        except TestCase.DoesNotExist:
                return JsonResponse({'error': 'Model not found'}, status=404)
        except Exception as e:
            return JsonResponse({'message': f'Error creating model: {str(e)}'}, status=500)
        
    elif request.method == 'GET':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = TestCase.objects.get(id=id)
        except TestCase.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        return JsonResponse(convert_testcase_to_json(model))
    
    elif request.method == 'DELETE':
        id = request.GET.get('id')
        if not id:
            return JsonResponse({'error': 'ID is required'}, status=400)
        
        try:
            model = TestCase.objects.get(id=id)
        except TestCase.DoesNotExist:
            return JsonResponse({'error': 'Model not found'}, status=404)
        
        model.delete()

        return JsonResponse({'message': 'Model deleted successfully'})
    
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)

    
def testcases(request):
    if request.method == 'GET':
        models = TestCase.objects.all()
        json_list = []
        for model in models:
            json_list.append(convert_testcase_to_json(model))

        return JsonResponse(json_list, safe=False)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)